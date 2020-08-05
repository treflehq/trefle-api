
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import UnknownItem from './Unknown'

const FieldTemperature = ({min, max}) => {

  if (!min || !max) {
    return <p>
      <b>Temperature:</b>{' Best between '}
      <UnknownItem value={min} name={'minimum_temperature_deg_c'} />
      {' '}and{' '}
      <UnknownItem value={max} name={'maximum_temperature_deg_c'} />
    </p>
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Temperature:</b>
          {' '}
          Best between <b>{min}</b>℃ and <b>{max}</b>℃
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldTemperature