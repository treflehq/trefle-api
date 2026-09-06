module Api
  module Sweep
    # Walks *everything* the shape and hot halves don't: every index page of
    # every paginated collection, then every record. Around a million paths, so
    # a run takes a slice and hands back a cursor to resume from — the point
    # being that consecutive runs cover new ground rather than replaying the
    # same sample.
    module Depth
      PER_PAGE = 20

      # Collections deep enough to be worth paginating through exhaustively.
      PAGINATED = {
        'species' => 'Species',
        'plants' => 'Plant',
        'genus' => 'Genus',
        'families' => 'Family',
        'distributions' => 'Zone'
      }.freeze

      # Record collections walked by primary key. Keyset rather than OFFSET: at
      # 400k rows in, `id > ?` answers in 3ms where OFFSET takes 114ms, and the
      # gap widens the further the sweep gets.
      RECORD_SEGMENTS = [
        { path: 'species', model: 'Species' },
        { path: 'plants', model: 'Plant' }
      ].freeze

      # Segment 0 is the index pages; the rest are the record collections.
      SEGMENT_COUNT = 1 + RECORD_SEGMENTS.length

      EMPTY_CURSOR = { 'segment' => 0, 'position' => nil }.freeze

      # Returns `limit` paths from where the last run stopped, plus the cursor
      # to resume from. Walks segments in order and wraps around at the end, so
      # the whole surface is covered cycle after cycle.
      def self.paths(cursor, limit)
        segment, position = read_cursor(cursor)
        paths = []
        exhausted = 0

        while paths.length < limit && exhausted <= SEGMENT_COUNT
          taken, next_position = slice(segment, position, limit - paths.length)
          paths.concat(taken)

          if next_position.nil?
            # Segment done: move to the next one, wrapping after the last.
            segment = (segment + 1) % SEGMENT_COUNT
            position = nil
            exhausted += 1
          else
            position = next_position
            exhausted = 0
          end
        end

        { paths: paths, cursor: { 'segment' => segment, 'position' => position } }
      end

      def self.read_cursor(cursor)
        return [0, nil] unless cursor.is_a?(Hash)

        [cursor['segment'].to_i % SEGMENT_COUNT, cursor['position']]
      end

      def self.slice(segment, position, limit)
        return [[], nil] unless limit.positive?

        segment.zero? ? index_slice(position, limit) : record_slice(segment - 1, position, limit)
      end

      # Index pages of every paginated collection, flattened into one ordered
      # space so a single integer says where the sweep is.
      def self.index_slice(position, limit)
        position = position.to_i
        counts = index_page_counts
        total = counts.sum {|(_, pages)| pages }
        return [[], nil] if position >= total

        last = [position + limit, total].min
        paths = (position...last).map {|ordinal| index_path_at(ordinal, counts) }
        [paths.compact, last >= total ? nil : last]
      end

      def self.index_page_counts
        PAGINATED.filter_map do |path, model|
          klass = model.safe_constantize
          next unless klass

          pages = (klass.count.to_f / PER_PAGE).ceil
          [path, pages] if pages.positive?
        end
      end

      def self.index_path_at(ordinal, counts)
        counts.each do |path, pages|
          return "/api/v1/#{path}?page=#{ordinal + 1}" if ordinal < pages

          ordinal -= pages
        end
        nil
      end

      # Keyset pagination: the position is the last id seen, not an offset.
      def self.record_slice(index, position, limit)
        spec = RECORD_SEGMENTS[index]
        klass = spec && spec[:model].safe_constantize
        return [[], nil] unless klass

        rows = klass.where('id > ?', position.to_i).order(:id).limit(limit).pluck(:id, :slug)
        return [[], nil] if rows.empty?

        paths = rows.filter_map {|(_, slug)| "/api/v1/#{spec[:path]}/#{slug}" if slug.present? }
        [paths, rows.length < limit ? nil : rows.last.first]
      end

      # How many paths a full cycle covers.
      def self.size
        index_page_counts.sum {|(_, pages)| pages } +
          RECORD_SEGMENTS.sum {|spec| spec[:model].safe_constantize&.count.to_i }
      end
    end
  end
end
