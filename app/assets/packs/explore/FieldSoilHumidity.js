
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'
import UnknownItem from './Unknown'

const FieldSoilHumidity = ({ value }) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Soil humidity:</b>{' '}<UnknownItem value={value} name={'ground_humidity'} />
    </p>
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil humidity:</b>
          {' '}
          <mark>TODO</mark>
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={value} leftIcon={'fill-drip'} />
      </div>
    </div>
  )
}

export default FieldSoilHumidity