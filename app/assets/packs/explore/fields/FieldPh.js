
import React from 'react'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInput from '../elements/ChangeInput'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldPh = ({min, max}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const realMin = firstNotNil(correction['ph_minimum'], min)
  const realMax = firstNotNil(correction['ph_maximum'], max)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Ph:</b>
            {' Best between  '}            
            <ChangeInput
              min={0}
              max={realMax}
              type="number"
              onChange={(e) => setField('ph_minimum', parseFloat(e.target.value))}
              value={realMin || 0.0}
            />
            {' and '}
            <ChangeInput
              type="number"
              min={realMin}
              max={14}
              onChange={(e) => setField('ph_maximum', parseFloat(e.target.value))}
              value={realMax || 0.0}
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
          <b>Ph:</b>
          {' '}
          Best between
          {' '}
          <b><UnknownItem value={realMin} name={'ph_minimum'} /></b>
          {' and '}
          <b><UnknownItem value={realMax} name={'ph_maximum'} /></b>
        </p>
      </div>
      <div className="column is-3">
      </div>
    </div>
  )
}

export default FieldPh