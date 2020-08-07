
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'

const FieldSoilNutriments = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil nutriments:</b>{' '}<UnknownItem value={value} name={'soil_nutriments'} />
    </p>
  }


  const legend = {
    1: 'Very low (≈100 µg N / l)', // hyperoligotrophiles
    2: 'Low (≈200 µg N / l)', // peroligotrophiles
    3: 'Low (≈300 µg N / l)', // oligotrophiles
    4: 'Low (≈400 µg N / l)', // méso - oligotrophiles
    5: 'Medium (≈500 µg N / l)', // mésotrophiles
    6: 'Medium (≈750 µg N / l)', // méso - eutrophiles
    7: 'High (≈1000 µg N / l)', // eutrophiles
    8: 'High (≈1250 µg N / l)', // pereutrophiles
    9: 'Very high (≈1500 µg N / l)', // hypereutrophiles
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil nutriments:</b>
          {' '}
          {legend[value]}
        </p>
      </div>
      <div className="column is-3">
        <Scale min={1} max={9} value={value} leftIcon={'cauldron'} />
      </div>
    </div>
  )
}

export default FieldSoilNutriments