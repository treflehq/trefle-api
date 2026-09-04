
import React from 'react'
import { range } from 'lodash'
import clsx from 'clsx'
import Icon from '../../shared/Icon'

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
    {leftIcon && <Icon name={leftIcon} /> || <span className="blanker" /> }
    <span className="scaleItemContainer">
      {values.map(v => <span key={v} className={clsx('scaleItem-step', v == value && 'current')}>
      </span>)}
    </span>
    {rightIcon && <Icon name={rightIcon} />}
  </span>)
}

export default Scale