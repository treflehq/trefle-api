
// import React from 'react'
// import Scale from '../elements/Scale'
// import UnknownItem from './Unknown'

// const FieldSoilHumidity = ({ value }) => {

//   if (value === null || value === undefined) {
//     return <p>
//       <b>Soil humidity:</b>{' '}<UnknownItem value={value} name={'ground_humidity'} />
//     </p>
//   }

//   const legend = {
//     1: 'Very low', // hyperxérophiles(sclérophiles, ligneuses microphylles, réviviscentes)
//     2: 'Low', // perxérophiles(caulocrassulescentes subaphylles, coussinets)
//     3: 'Low', // xérophiles(velues, aiguillonnées, cuticule épaisse)
//     4: 'Medium', // mésoxérophiles
//     5: 'Medium (no flooding)', // mésohydriques(jamais inondé, feuilles malacophylles)
//     6: 'High', // mésohygroclines, mésohygrophiles
//     7: 'High (few weeks flooding)', // hygrophiles(durée d\'inondation en quelques semaines) 
//     8: 'Very high (few months flooding)', // hydrophiles (durée d\'inondation en plusieurs mois)
//     9: 'Very high (amphiphytes)', // amphibies saisonnières(hélophytes exondés une partie minoritaire de l’année)
//     10: 'Very high (amphiphytes)', // amphibies permanentes(hélophytes semi- émergés à base toujours noyée)
//     11: 'Aquatic (floating or 0 to 50 cm deep', // aquatiques superficielles(0 - 50 cm) ou flottantes
//     12: 'Aquatic (submerged, 1 to 3 meters deep)', // aquatiques profondes(1 - 3 m) ou intra - aquatiques
//   }

//   return (
//     <div className="columns">
//       <div className="column is-9">
//         <p>
//           <b>Soil humidity:</b>
//           {' '}
//           {legend[value]}
//         </p>
//       </div>
//       <div className="column is-3">
//         <Scale min={0} max={12} value={value} leftIcon={'fill-drip'} />
//       </div>
//     </div>
//   )
// }

// export default FieldSoilHumidity


import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import MappedValue from '../elements/MappedValue'
import { invert, reverse } from 'lodash'


const FieldSoilHumidity = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const realValue = firstNotNil(correction[name], value)


  const options = {
    'Extremely low (always dry)': 1, // hyperxérophiles(sclérophiles, ligneuses microphylles, réviviscentes)
    'Very low (dry)': 2, // perxérophiles(caulocrassulescentes subaphylles, coussinets)
    'Low (dry most of the time)': 3, // xérophiles(velues, aiguillonnées, cuticule épaisse)
    'Medium': 4, // mésoxérophiles
    'Medium (no flooding)': 5, // mésohydriques(jamais inondé, feuilles malacophylles)
    'High': 6, // mésohygroclines, mésohygrophiles
    'High (few weeks flooding)': 7, // hygrophiles(durée d\'inondation en quelques semaines) 
    'Very high (few months flooding)': 8, // hydrophiles (durée d\'inondation en plusieurs mois)
    'Very high (amphiphytes)': 9, // amphibies saisonnières(hélophytes exondés une partie minoritaire de l’année)
    'Very high, root is always under water (amphiphytes)': 10, // amphibies permanentes(hélophytes semi- émergés à base toujours noyée)
    'Aquatic (floating or 0 to 50 cm deep': 11, // aquatiques superficielles(0 - 50 cm) ou flottantes
    'Aquatic (submerged, 1 to 3 meters deep)': 12, // aquatiques profondes(1 - 3 m) ou intra - aquatiques
  }

  if (edit) {
    console.log({ realValue, reverse: invert(options) });
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Soil humidity:</b>
            {' '}

            <ChangeInputRange
              min={1}
              max={12}
              onChange={(e) => setField(name, parseInt(e.target.value))}
              value={realValue}
            />

            <span>
              {' '}
              {invert(options)[realValue]}
            </span>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil humidity:</b>
          {' '}
          <UnknownItem value={realValue} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={12} value={realValue} leftIcon={'fill-drip'} />
      </div>
    </div>
  )
}

export default FieldSoilHumidity