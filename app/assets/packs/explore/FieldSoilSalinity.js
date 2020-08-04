
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'
import UnknownItem from './Unknown'

const FieldSoilSalinity = ({ value }) => {

  if (value === null || value === undefined) {
    return <UnknownItem value={value} name={'soil_salinity'} />
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil salinity:</b>
          {' '}
          <mark>TODO</mark>
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={value} leftIcon={''} />
      </div>
    </div>
  )
}

export default FieldSoilSalinity