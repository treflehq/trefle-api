
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'

const FieldSoilSalinity = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil salinity:</b>{' '}<UnknownItem value={value} name={'soil_salinity'} />
    </p>
  }


  const legend = {
    0: 'Untolerant',
    1: <span>0 - 0.1 % <sup>Cl−</sup></span>,     // hyperoligohalines
    2: <span>0.1 - 0.3 % <sup>Cl−</sup></span>,  // peroligohalines
    3: <span>0.3 - 0.5 % <sup>Cl−</sup></span>,  // oligohalines
    4: <span>0.5 - 0.7 % <sup>Cl−</sup></span>,  // meso - oligohalines
    5: <span>0.7 - 0.9 % <sup>Cl−</sup></span>,  // mesohalines
    6: <span>0.9 - 1.2 % <sup>Cl−</sup></span>,  // meso - euhalines
    7: <span>1.2 - 1.6 % <sup>Cl−</sup></span>,  // euhalines
    8: <span>1.6 - 2.3 % <sup>Cl−</sup></span>,  // polyhalines
    9: <span>&gt; 2.3 % <sup>Cl−</sup></span>,       // hyperhalines
  }


  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil salinity:</b>
          {' '}
          {legend[value]}
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={value} leftIcon={'atom-alt'} />
      </div>
    </div>
  )
}

export default FieldSoilSalinity