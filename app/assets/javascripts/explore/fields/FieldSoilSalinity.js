import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import { invert, reverse } from 'lodash'

const FieldSoilSalinity = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    'Untolerant': 0,
    '0% - 0.1% Cl−': 1,     // hyperoligohalines
    '0.1% - 0.3% Cl−': 2,  // peroligohalines
    '0.3% - 0.5% Cl−': 3,  // oligohalines
    '0.5% - 0.7% Cl−': 4,  // meso - oligohalines
    '0.7% - 0.9% Cl−': 5,  // mesohalines
    '0.9% - 1.2% Cl−': 6,  // meso - euhalines
    '1.2% - 1.6% Cl−': 7,  // euhalines
    '1.6% - 2.3% Cl−': 8,  // polyhalines
    '> 2.3% Cl−': 9,       // hyperhalines
  }

  const realValue = firstNotNil(correction[name], value)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Soil salinity:</b>
            {' '}

            <ChangeInputRange
              min={0}
              max={9}
              onChange={(e) => setField(name, parseInt(e.target.value))}
              value={realValue}
            />

            <span>
              {' '}
              {invert(options)[realValue]}
            </span>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Soil salinity:</b>
          {' '}
          <UnknownItem value={value} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={realValue} leftIcon={'atom-alt'} />
      </div>
    </div>
  )
}

export default FieldSoilSalinity