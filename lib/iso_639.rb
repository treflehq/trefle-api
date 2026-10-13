# ISO 639-1 language codes and their ISO 639-2 equivalents.
#
# The common names were imported from sources that tag their language
# differently: two-letter ISO 639-1 codes (`fr`), three-letter ISO 639-2/T
# or 639-2/B codes (`fra`, `fre`), and regional tags (`pt-br`, `zh-hant`).
# The API speaks ISO 639-1 only (`?lang=fr`); this table maps every stored
# spelling back to it.
module Iso639
  # ISO 639-1 => [ISO 639-2/T, ISO 639-2/B when it differs]
  CODES = {
    'aa' => %w[aar], 'ab' => %w[abk], 'ae' => %w[ave], 'af' => %w[afr], 'ak' => %w[aka],
    'am' => %w[amh], 'an' => %w[arg], 'ar' => %w[ara], 'as' => %w[asm], 'av' => %w[ava],
    'ay' => %w[aym], 'az' => %w[aze], 'ba' => %w[bak], 'be' => %w[bel], 'bg' => %w[bul],
    'bh' => %w[bih], 'bi' => %w[bis], 'bm' => %w[bam], 'bn' => %w[ben], 'bo' => %w[bod tib],
    'br' => %w[bre], 'bs' => %w[bos], 'ca' => %w[cat], 'ce' => %w[che], 'ch' => %w[cha],
    'co' => %w[cos], 'cr' => %w[cre], 'cs' => %w[ces cze], 'cu' => %w[chu], 'cv' => %w[chv],
    'cy' => %w[cym wel], 'da' => %w[dan], 'de' => %w[deu ger], 'dv' => %w[div], 'dz' => %w[dzo],
    'ee' => %w[ewe], 'el' => %w[ell gre], 'en' => %w[eng], 'eo' => %w[epo], 'es' => %w[spa],
    'et' => %w[est], 'eu' => %w[eus baq], 'fa' => %w[fas per], 'ff' => %w[ful], 'fi' => %w[fin],
    'fj' => %w[fij], 'fo' => %w[fao], 'fr' => %w[fra fre], 'fy' => %w[fry], 'ga' => %w[gle],
    'gd' => %w[gla], 'gl' => %w[glg], 'gn' => %w[grn], 'gu' => %w[guj], 'gv' => %w[glv],
    'ha' => %w[hau], 'he' => %w[heb], 'hi' => %w[hin], 'ho' => %w[hmo], 'hr' => %w[hrv],
    'ht' => %w[hat], 'hu' => %w[hun], 'hy' => %w[hye arm], 'hz' => %w[her], 'ia' => %w[ina],
    'id' => %w[ind], 'ie' => %w[ile], 'ig' => %w[ibo], 'ii' => %w[iii], 'ik' => %w[ipk],
    'io' => %w[ido], 'is' => %w[isl ice], 'it' => %w[ita], 'iu' => %w[iku], 'ja' => %w[jpn],
    'jv' => %w[jav], 'ka' => %w[kat geo], 'kg' => %w[kon], 'ki' => %w[kik], 'kj' => %w[kua],
    'kk' => %w[kaz], 'kl' => %w[kal], 'km' => %w[khm], 'kn' => %w[kan], 'ko' => %w[kor],
    'kr' => %w[kau], 'ks' => %w[kas], 'ku' => %w[kur], 'kv' => %w[kom], 'kw' => %w[cor],
    'ky' => %w[kir], 'la' => %w[lat], 'lb' => %w[ltz], 'lg' => %w[lug], 'li' => %w[lim],
    'ln' => %w[lin], 'lo' => %w[lao], 'lt' => %w[lit], 'lu' => %w[lub], 'lv' => %w[lav],
    'mg' => %w[mlg], 'mh' => %w[mah], 'mi' => %w[mri mao], 'mk' => %w[mkd mac], 'ml' => %w[mal],
    'mn' => %w[mon], 'mr' => %w[mar], 'ms' => %w[msa may], 'mt' => %w[mlt], 'my' => %w[mya bur],
    'na' => %w[nau], 'nb' => %w[nob], 'nd' => %w[nde], 'ne' => %w[nep], 'ng' => %w[ndo],
    'nl' => %w[nld dut], 'nn' => %w[nno], 'no' => %w[nor], 'nr' => %w[nbl], 'nv' => %w[nav],
    'ny' => %w[nya], 'oc' => %w[oci], 'oj' => %w[oji], 'om' => %w[orm], 'or' => %w[ori],
    'os' => %w[oss], 'pa' => %w[pan], 'pi' => %w[pli], 'pl' => %w[pol], 'ps' => %w[pus],
    'pt' => %w[por], 'qu' => %w[que], 'rm' => %w[roh], 'rn' => %w[run], 'ro' => %w[ron rum],
    'ru' => %w[rus], 'rw' => %w[kin], 'sa' => %w[san], 'sc' => %w[srd], 'sd' => %w[snd],
    'se' => %w[sme], 'sg' => %w[sag], 'si' => %w[sin], 'sk' => %w[slk slo], 'sl' => %w[slv],
    'sm' => %w[smo], 'sn' => %w[sna], 'so' => %w[som], 'sq' => %w[sqi alb], 'sr' => %w[srp],
    'ss' => %w[ssw], 'st' => %w[sot], 'su' => %w[sun], 'sv' => %w[swe], 'sw' => %w[swa],
    'ta' => %w[tam], 'te' => %w[tel], 'tg' => %w[tgk], 'th' => %w[tha], 'ti' => %w[tir],
    'tk' => %w[tuk], 'tl' => %w[tgl], 'tn' => %w[tsn], 'to' => %w[ton], 'tr' => %w[tur],
    'ts' => %w[tso], 'tt' => %w[tat], 'tw' => %w[twi], 'ty' => %w[tah], 'ug' => %w[uig],
    'uk' => %w[ukr], 'ur' => %w[urd], 'uz' => %w[uzb], 've' => %w[ven], 'vi' => %w[vie],
    'vo' => %w[vol], 'wa' => %w[wln], 'wo' => %w[wol], 'xh' => %w[xho], 'yi' => %w[yid],
    'yo' => %w[yor], 'za' => %w[zha], 'zh' => %w[zho chi], 'zu' => %w[zul]
  }.freeze

  ALPHA3_TO_ALPHA2 = CODES.each_with_object({}) do |(alpha2, alpha3s), map|
    alpha3s.each {|alpha3| map[alpha3] = alpha2 }
  end.freeze

  # The ISO 639-1 code of a stored language tag, or nil when it has none:
  # `fr`, `fra`, `fre` and `FR` give `fr`; `pt-br` gives `pt`; a blank tag
  # or a language without a two-letter code gives nil.
  def self.alpha2(tag)
    primary = tag.to_s.strip.downcase.split(/[-_]/).first
    return nil if primary.blank?
    return primary if CODES.key?(primary)

    ALPHA3_TO_ALPHA2[primary]
  end
end
