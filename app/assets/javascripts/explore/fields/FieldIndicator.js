import React, { useContext } from 'react'
import { invert } from 'lodash'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import { indicator, indicatorOptions } from '../constants/ecologicalIndicators'

// An ecological indicator value (light, humidities, nutriments, salinity):
// an ordinal Ellenberg class shown as "7 / 9 · half-light to light" next to
// its meter, never converted to a measurement. `name` is the species column
// a correction targets; the label, range and class names come with the page.
const FieldIndicator = ({
  value,
  name,
  leftIcon = null,
  rightIcon = null
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const spec = indicator(name)
  if (!spec) return null

  const options = indicatorOptions(spec)
  const realValue = firstNotNil(correction[name], value)

  if (edit) {
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b title={spec.indicator}>{spec.label}:</b>
            {' '}
            <ChangeInputRange
              min={spec.min}
              max={spec.max}
              onChange={(e) => setField(name, parseInt(e.target.value, 10))}
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
          <b title={spec.indicator}>{spec.label}:</b>
          {' '}
          <UnknownItem value={value} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={spec.min} max={spec.max} value={realValue} leftIcon={leftIcon} rightIcon={rightIcon} />
      </div>
    </div>
  )
}

export default FieldIndicator
