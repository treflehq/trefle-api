# Common names were collected under two language code systems: the old
# crawlers wrote ISO 639-1 (en, fr), GBIF's API answers ISO 639-2 (eng, fra).
# The same name ends up twice on a record, and anything that reads a language
# (Species#regenerate_tokens! reads 'en' for the search token) sees half the
# data. Codes with a two-letter equivalent are rewritten to it, then the
# duplicates (same record, same name, same language, case-insensitive) are
# dropped, lowest id kept. BCP 47 tags with a region (pt-br, zh-tw) are left as
# they are: the region is information. Replayable; dry run by default (#419).
module Migrators
  class CommonNameLanguages

    # ISO 639-2 (bibliographic and terminological) -> ISO 639-1.
    ISO_639_2_TO_1 = {
      'aar' => 'aa', 'abk' => 'ab', 'afr' => 'af', 'aka' => 'ak', 'alb' => 'sq', 'sqi' => 'sq',
      'amh' => 'am', 'ara' => 'ar', 'arg' => 'an', 'arm' => 'hy', 'hye' => 'hy', 'asm' => 'as',
      'ava' => 'av', 'ave' => 'ae', 'aym' => 'ay', 'aze' => 'az', 'bak' => 'ba', 'bam' => 'bm',
      'baq' => 'eu', 'eus' => 'eu', 'bel' => 'be', 'ben' => 'bn', 'bih' => 'bh', 'bis' => 'bi',
      'bos' => 'bs', 'bre' => 'br', 'bul' => 'bg', 'bur' => 'my', 'mya' => 'my', 'cat' => 'ca',
      'cha' => 'ch', 'che' => 'ce', 'chi' => 'zh', 'zho' => 'zh', 'chu' => 'cu', 'chv' => 'cv',
      'cor' => 'kw', 'cos' => 'co', 'cre' => 'cr', 'cze' => 'cs', 'ces' => 'cs', 'dan' => 'da',
      'div' => 'dv', 'dut' => 'nl', 'nld' => 'nl', 'dzo' => 'dz', 'eng' => 'en', 'epo' => 'eo',
      'est' => 'et', 'ewe' => 'ee', 'fao' => 'fo', 'fij' => 'fj', 'fin' => 'fi', 'fre' => 'fr',
      'fra' => 'fr', 'fry' => 'fy', 'ful' => 'ff', 'geo' => 'ka', 'kat' => 'ka', 'ger' => 'de',
      'deu' => 'de', 'gla' => 'gd', 'gle' => 'ga', 'glg' => 'gl', 'glv' => 'gv', 'gre' => 'el',
      'ell' => 'el', 'grn' => 'gn', 'guj' => 'gu', 'hat' => 'ht', 'hau' => 'ha', 'heb' => 'he',
      'her' => 'hz', 'hin' => 'hi', 'hmo' => 'ho', 'hrv' => 'hr', 'hun' => 'hu', 'ibo' => 'ig',
      'ice' => 'is', 'isl' => 'is', 'ido' => 'io', 'iii' => 'ii', 'iku' => 'iu', 'ile' => 'ie',
      'ina' => 'ia', 'ind' => 'id', 'ipk' => 'ik', 'ita' => 'it', 'jav' => 'jv', 'jpn' => 'ja',
      'kal' => 'kl', 'kan' => 'kn', 'kas' => 'ks', 'kau' => 'kr', 'kaz' => 'kk', 'khm' => 'km',
      'kik' => 'ki', 'kin' => 'rw', 'kir' => 'ky', 'kom' => 'kv', 'kon' => 'kg', 'kor' => 'ko',
      'kua' => 'kj', 'kur' => 'ku', 'lao' => 'lo', 'lat' => 'la', 'lav' => 'lv', 'lim' => 'li',
      'lin' => 'ln', 'lit' => 'lt', 'ltz' => 'lb', 'lub' => 'lu', 'lug' => 'lg', 'mac' => 'mk',
      'mkd' => 'mk', 'mah' => 'mh', 'mal' => 'ml', 'mao' => 'mi', 'mri' => 'mi', 'mar' => 'mr',
      'may' => 'ms', 'msa' => 'ms', 'mlg' => 'mg', 'mlt' => 'mt', 'mon' => 'mn', 'nau' => 'na',
      'nav' => 'nv', 'nbl' => 'nr', 'nde' => 'nd', 'ndo' => 'ng', 'nep' => 'ne', 'nno' => 'nn',
      'nob' => 'nb', 'nor' => 'no', 'nya' => 'ny', 'oci' => 'oc', 'oji' => 'oj', 'ori' => 'or',
      'orm' => 'om', 'oss' => 'os', 'pan' => 'pa', 'per' => 'fa', 'fas' => 'fa', 'pli' => 'pi',
      'pol' => 'pl', 'por' => 'pt', 'pus' => 'ps', 'que' => 'qu', 'roh' => 'rm', 'rum' => 'ro',
      'ron' => 'ro', 'run' => 'rn', 'rus' => 'ru', 'sag' => 'sg', 'san' => 'sa', 'sin' => 'si',
      'slo' => 'sk', 'slk' => 'sk', 'slv' => 'sl', 'sme' => 'se', 'smo' => 'sm', 'sna' => 'sn',
      'snd' => 'sd', 'som' => 'so', 'sot' => 'st', 'spa' => 'es', 'srd' => 'sc', 'srp' => 'sr',
      'ssw' => 'ss', 'sun' => 'su', 'swa' => 'sw', 'swe' => 'sv', 'tah' => 'ty', 'tam' => 'ta',
      'tat' => 'tt', 'tel' => 'te', 'tgk' => 'tg', 'tgl' => 'tl', 'tha' => 'th', 'tib' => 'bo',
      'bod' => 'bo', 'tir' => 'ti', 'ton' => 'to', 'tsn' => 'tn', 'tso' => 'ts', 'tuk' => 'tk',
      'tur' => 'tr', 'twi' => 'tw', 'uig' => 'ug', 'ukr' => 'uk', 'urd' => 'ur', 'uzb' => 'uz',
      'ven' => 've', 'vie' => 'vi', 'vol' => 'vo', 'wel' => 'cy', 'cym' => 'cy', 'wln' => 'wa',
      'wol' => 'wo', 'xho' => 'xh', 'yid' => 'yi', 'yor' => 'yo', 'zha' => 'za', 'zul' => 'zu'
    }.freeze

    Result = Struct.new(:normalised, :duplicates_removed, :by_code, keyword_init: true)

    def self.run(dry_run: true)
      by_code = ::CommonName.where(lang: ISO_639_2_TO_1.keys).group(:lang).count
      result = Result.new(normalised: by_code.values.sum, duplicates_removed: duplicate_ids.size, by_code: by_code)

      unless dry_run
        by_code.each_key {|three| ::CommonName.where(lang: three).update_all(lang: ISO_639_2_TO_1[three]) } # rubocop:disable Rails/SkipsModelValidations
        result.duplicates_removed = ::CommonName.where(id: duplicate_ids).delete_all
      end

      Rails.logger.info("[CommonNameLanguages]#{' DRY RUN' if dry_run} #{result.to_h.except(:by_code)}")
      result
    end

    # Ids of the rows that duplicate a lower-id row once languages are
    # normalised, so the dry run counts what the real run removes.
    def self.duplicate_ids
      mapping = ISO_639_2_TO_1.map {|three, two| "(#{::CommonName.connection.quote(three)}, #{::CommonName.connection.quote(two)})" }.join(', ')
      ::CommonName.connection.select_values(<<~SQL.squish)
        WITH m(three, two) AS (VALUES #{mapping}),
             n AS (SELECT c.id, c.record_type, c.record_id, lower(c.name) AS name, coalesce(m.two, c.lang, '') AS lang
                   FROM common_names c LEFT JOIN m ON m.three = c.lang)
        SELECT DISTINCT a.id FROM n a JOIN n b
          ON a.record_type = b.record_type AND a.record_id = b.record_id AND a.name = b.name AND a.lang = b.lang AND a.id > b.id
      SQL
    end
    private_class_method :duplicate_ids

  end
end
