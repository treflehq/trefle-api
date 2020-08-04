
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'

const FieldTemperature = ({min, max}) => {

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Temperature:</b>
          {' '}
          <mark>TODO</mark>
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldTemperature