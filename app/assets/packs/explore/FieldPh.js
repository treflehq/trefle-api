
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import UnknownItem from './Unknown'

const FieldPh = ({min, max}) => {

  if (!min || !max) {
    return <p>
      <b>Ph:</b>{' Best between '}
      <UnknownItem value={min} name={'ph_minimum'} />
      {' '}and{' '}
      <UnknownItem value={max} name={'ph_maximum'} />
    </p>
  }

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