
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'
import UnknownItem from './Unknown'

const FieldSoilNutriments = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil nutriments:</b>{' '}<UnknownItem value={value} name={'soil_nutriments'} />
    </p>
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil nutriments:</b>
          {' '}
          <mark>TODO</mark>
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={value} leftIcon={'cauldron'} />
      </div>
    </div>
  )
}

export default FieldSoilNutriments