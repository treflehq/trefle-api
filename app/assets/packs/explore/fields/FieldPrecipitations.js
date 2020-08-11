
import React from 'react'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldPrecipitations = ({ min, max }) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const realMin = firstNotNil(correction['minimum_precipitation_mm'], min)
  const realMax = firstNotNil(correction['maximum_precipitation_mm'], max)

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
              onChange={(e) => setField('minimum_precipitation_mm', parseFloat(e.target.value))}
              value={realMin || 0.0}
              addon={'mm'}
            />
            {' and '}
            <ChangeInput
              type="number"
              // min={realMin}
              max={5000}
              onChange={(e) => setField('maximum_precipitation_mm', parseFloat(e.target.value))}
              value={realMax || 0.0}
              addon={'mm'}
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