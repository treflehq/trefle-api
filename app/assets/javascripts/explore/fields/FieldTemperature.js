

import React from 'react'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldTemperature = ({ min, max }) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const realMin = firstNotNil(correction['minimum_temperature_deg_c'], min)
  const realMax = firstNotNil(correction['maximum_temperature_deg_c'], max)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Temperature:</b>
            {' Best between  '}
            <ChangeInput
              min={-60}
              // max={realMax}
              type="number"
              onChange={(e) => setField('minimum_temperature_deg_c', parseFloat(e.target.value))}
              value={realMin || 0.0}
              addon={'°C'}
            />
            {' and '}
            <ChangeInput
              type="number"
              // min={realMin}
              max={60}
              onChange={(e) => setField('maximum_temperature_deg_c', parseFloat(e.target.value))}
              value={realMax || 0.0}
              addon={'°C'}
            />
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Temperature:</b>
          {' '}
          Best between
          {' '}
          <b><UnknownItem value={realMin} name={'minimum_temperature_deg_c'} />°C</b>
          {' and '}
          <b><UnknownItem value={realMax} name={'maximum_temperature_deg_c'} />°C</b>
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldTemperature