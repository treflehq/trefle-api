
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'
import UnknownItem from './Unknown'

const FieldAtmosphericHumidity = ({
  value
}) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Atmospheric Humidity:</b>{' '}<UnknownItem value={value} name={'atmospheric_humidity'} />
    </p>
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Atmospheric Humidity:</b>
          {' '}
          Around { value * 10}%
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={10} value={value} leftIcon={'tint'} />
      </div>
    </div>
  )
}

export default FieldAtmosphericHumidity