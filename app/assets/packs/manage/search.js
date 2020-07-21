
import { capitalize } from 'lodash';
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import { useEffect } from 'react';
import AsyncSelect from 'react-select/async';


const SpeciesItem = ({
  image_url,
  scientific_name,
  common_name,
  synonyms,
  status,
  rank,
  family,
  author
}) => {

  return (<div className="speciesItem">
    <aside style={{ backgroundImage: `url(${image_url})`}}>
      {/* <img src={image_url} alt={scientific_name}/> */}
    </aside>
    <main>
      <h2><i>{scientific_name}</i> {author ? <small>{author}</small> : ''}</h2>
      <p>
        {common_name && <span>Also called {capitalize(common_name)}.{' '}</span>}
        Is a {rank} of the <b>{family}</b> family.
      </p>
      {synonyms.length > 0 && <small>Synonyms: {synonyms.slice(0, 2).join(' or ')}</small>}
    </main>
  </div>)
}

const SearchBar = (props) => {

  const [query, setQuery] = useState('')
  // const [response, setresponse] = useState({})
  // const [options, setOptions] = useState([])
  // const [value, setValue] = useState('')

  // useEffect(() => {
  //   async function fetchData() {
  //     if (query && query.length > 0) {
  //       const r = await axios.get(`/api/v1/species/search?token=${temp_token}&q=${query}&limit=3`)
  //       // const json = await r.json()
  //       setOptions()
  //     }
  //   }
  //   fetchData()
  // }, [query])

  // const onQueryChange = (q) => {
  //   setQuery(q)
  // }
  
  const promiseOptions = async (query) => {
    const r = await axios.get(`/api/v1/species/search?token=${temp_token}&q=${query}&limit=3`)
    return r.data.data.map(e => ({ label: e.scientific_name, value: e.slug }))
  }
  const customStyles = {
    option: (provided, state) => ({
      ...provided,
      color: state.isSelected ? 'black' : '#41b913',
      padding: 5,
    }),
    control: (provided) => ({
      // none of react-select's styles are passed to <Control />
      ...provided,
      width: 250,
      display: 'flex'
    }),
  }

  const onChange = (a, b) => {
    console.log({ a, b });
    window.location.assign(`/management/species/${a.value}`)
  }

  return (<>
    <AsyncSelect cacheOptions
      onChange={onChange}
      styles={customStyles}
      defaultOptions
      loadOptions={promiseOptions}
    />
  </>)
}


document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#admin-search").length > 0) {
    const domContainer = document.querySelector('#admin-search');
    ReactDOM.render(React.createElement(SearchBar), domContainer);
  }
})
