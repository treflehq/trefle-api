
import React from 'react'
import UnknownItem from './Unknown'

const FieldPrecipitations = ({min, max}) => {
  
  if (!min || !max) {
    return <p>
      <b>Precipitations:</b>{' Best between '}
      <UnknownItem value={min} name={'minimum_precipitation_mm'} />
      {' '}and{' '}
      <UnknownItem value={max} name={'maximum_precipitation_mm'} />
    </p>
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Precipitations:</b>
          {' '}
          Best between <b>{min}</b>mm and <b>{max}</b>mm per year
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldPrecipitations