# Renders citation entries as BibTeX and RIS, for CitationHelper: Trefle's
# own entry and the structured works of the sources it co-cites
# (CitationSources::REFERENCES).
module CitationFormats
  module_function

  # entries: [[field, value], ...]; blank values are left out.
  def bibtex(type, key, entries)
    body = entries.select {|_field, value| value.present? }
      .map {|field, value| "  #{field} = {#{value}}" }
    "@#{type}{#{key},\n#{body.join(",\n")}\n}"
  end

  # lines: [[tag, value], ...]; nil values are left out, ER closes the entry.
  def ris(lines)
    kept = lines.reject {|_tag, value| value.nil? }
    [*kept, ['ER', '']].map {|tag, value| "#{tag}  - #{value}" }.join("\n")
  end

  def bibtex_work(work)
    bibtex('article', work[:key], [
             ['author', work[:authors].join(' and ')],
             ['title', "{#{work[:title]}}"],
             ['journal', work[:journal]],
             ['year', work[:year].to_s],
             ['volume', work[:volume]],
             ['number', work[:number]],
             ['pages', work[:pages]],
             ['doi', work[:doi]]
           ])
  end

  def ris_work(work)
    first, last = work[:pages].to_s.split(/-+/)
    authors = work[:authors].reject {|author| author == 'others' }.map {|author| ['AU', author] }
    ris([
          %w[TY JOUR], *authors,
          ['TI', work[:title]], ['JO', work[:journal]], ['PY', work[:year].to_s],
          ['VL', work[:volume]], ['IS', work[:number]], ['SP', first], ['EP', last],
          ['DO', work[:doi]]
        ])
  end
end
