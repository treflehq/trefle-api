
import React from 'react'
import clsx from 'clsx';

const Calendar = ({
  bloom,
  fruit,
  growth
}) => {

  const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']

  const renderHeaders = () => {
    return <thead>
      <tr>
        <th></th>
        {months.map(m => <th key={m}>{m}</th>)}
      </tr>
    </thead>
  }

  const renderRows = (name, rows, label) => {
    const newRows = months.map(m => rows.includes(m))
    return (<tr className={`row-${name}`}>
      <td>{ label }</td>
      {newRows.map((m, index) => {
        return (<td key={index}>
          <div className={clsx(m && 'is-active', m && !newRows[index + 1] && 'is-last', !newRows[index - 1] && m && 'is-first')}/>
        </td>)
      })}
    </tr>)
  }

  return (<div className="CalendarItem is-hidden-touch">
    <table>
      {renderHeaders()}
      <tbody>
        {growth && renderRows('growth', growth, 'Growing')}
        {bloom && renderRows('bloom', bloom, 'Blooming')}
        {fruit && renderRows('fruit', fruit, 'Fruits')}
      </tbody>
    </table>
  </div>)
}

export default Calendar