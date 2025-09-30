
import React from 'react'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldPrecipitations = ({
  min,
  max,
  unit = 'mm'
}) => {
  const { edit, correction, setFields } = useContext(CorrectionContext)
  const realMin = firstNotNil(correction['minimum_precipitation_value'], min)
  const realMax = firstNotNil(correction['maximum_precipitation_value'], max)

  const onChange = (name, v) => {
    setFields({
      [`${name}_value`]: v.target.value && parseInt(v.target.value),
      [`${name}_unit`]: unit,
    })
  }

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Precipitations:</b>
            {' Best between  '}
            <ChangeInput
              min={0}
              // max={realMax}
              type="number"
              onChange={(e) => onChange('minimum_precipitation', e)}
              value={realMin || ''}
              addon={unit}
            />
            {' and '}
            <ChangeInput
              type="number"
              // min={realMin}
              max={5000}
              onChange={(e) => onChange('maximum_precipitation', e)}
              value={realMax || ''}
              addon={unit}
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
          <b>Precipitations:</b>
          {' '}
          Best between
          {' '}
          <b><UnknownItem value={realMin} name={'minimum_precipitation_mm'} /></b>
          {' and '}
          <b><UnknownItem value={realMax} name={'maximum_precipitation_mm'} /></b>
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldPrecipitations