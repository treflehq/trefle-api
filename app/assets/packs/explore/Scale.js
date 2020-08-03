
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'

const Scale = ({
  label,
  value,
  min = 0,
  max = 10,
  step = 1
}) => {

  const values = range(min, max + 1, step)
  return (<span className="scaleItem">
    <b>{label}</b>:{' '}
    {values.map(v => <div className={clsx('scaleItem-step', v == value && 'current')}>
      { v }
    </div>)}
  </span>)
}

export default Scale