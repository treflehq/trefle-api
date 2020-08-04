
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Scale from './Scale'

const FieldPh = ({min, max}) => {

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Ph:</b>
          {' '}
          Best between <b>{min}</b> and <b>{max}</b>
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldPh