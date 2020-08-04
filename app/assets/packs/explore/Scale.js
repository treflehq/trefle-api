
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'

const Scale = ({
  label,
  value,
  leftIcon = null,
  rightIcon = null,
  min = 0,
  max = 10,
  step = 1
}) => {


  const values = range(min, max + 1, step)
  return (<span className="scaleItem">
    {leftIcon && <i className={clsx('fad', `fa-${leftIcon}`)} /> || <span className="blanker" /> }
    <span className="scaleItemContainer">
      {values.map(v => <span className={clsx('scaleItem-step', v == value && 'current')}>
      </span>)}
    </span>
    {rightIcon && <i className={clsx('fad', `fa-${rightIcon}`)} />}
  </span>)
}

export default Scale