
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'

const FieldSoilHumidity = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil humidity:</b>{' '}<UnknownItem value={value} name={'ground_humidity'} />
    </p>
  }

  const legend = {
    1: 'Very low', // hyperxérophiles(sclérophiles, ligneuses microphylles, réviviscentes)
    2: 'Low', // perxérophiles(caulocrassulescentes subaphylles, coussinets)
    3: 'Low', // xérophiles(velues, aiguillonnées, cuticule épaisse)
    4: 'Medium', // mésoxérophiles
    5: 'Medium (no flooding)', // mésohydriques(jamais inondé, feuilles malacophylles)
    6: 'High', // mésohygroclines, mésohygrophiles
    7: 'High (few weeks flooding)', // hygrophiles(durée d\'inondation en quelques semaines) 
    8: 'Very high (few months flooding)', // hydrophiles (durée d\'inondation en plusieurs mois)
    9: 'Very high (amphiphytes)', // amphibies saisonnières(hélophytes exondés une partie minoritaire de l’année)
    10: 'Very high (amphiphytes)', // amphibies permanentes(hélophytes semi- émergés à base toujours noyée)
    11: 'Aquatic (floating or 0 to 50 cm deep', // aquatiques superficielles(0 - 50 cm) ou flottantes
    12: 'Aquatic (submerged, 1 to 3 meters deep)', // aquatiques profondes(1 - 3 m) ou intra - aquatiques
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil humidity:</b>
          {' '}
          {legend[value]}
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={12} value={value} leftIcon={'fill-drip'} />
      </div>
    </div>
  )
}

export default FieldSoilHumidity