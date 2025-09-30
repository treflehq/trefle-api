

import React from 'react'
import Select from 'react-select'
import { map, isNil } from 'lodash'

const ChangeInputSelect = ({
  multiple = false,
  allowNew = false,
  className = 'inline-select',
  onChange,
  value,
  addon,
  placeholder,
  options,
  ...props
}) => {

  const selectOptions = map(options, (value, label) => ({ value, label }))

  const onChangeMultiple = (a, b, c) => {
    console.log({ a, b, c });
    return onChange(a ? a.map(e => e.value) : null)
  }
  const onChangeSingle = (a, b, c) => {
    console.log({ a, b, c });
    return onChange(a ? a.value : null)
  }

  if (multiple) {
    const selectedValue = isNil(value) ? null : selectOptions.filter(e => [...value].includes(e.value))
    console.log({ selectOptions, selectedValue, value });

    return (<span className="fieldItem edit">
      <Select
        defaultValue={selectedValue}
        isMulti
        options={selectOptions}
        className={className}
        placeholder={placeholder || 'Select...'}
        onChange={onChangeMultiple}
        classNamePrefix="select"
        width='200px'
      />
      <span>{addon}</span>
    </span>)
  } else {
    return (<span className="fieldItem edit">
      <Select
        defaultValue={selectOptions.filter(e => e.value === value)}
        options={selectOptions}
        className={className}
        placeholder={placeholder || 'Select...'}
        onChange={onChangeSingle}
        classNamePrefix="select"
        width='200px'
      />
      <span>{addon}</span>
    </span>)
  }

}

export default ChangeInputSelect

