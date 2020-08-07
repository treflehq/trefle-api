
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import Species from './Species';
import { useEffect } from 'react';
import CorrectionContext from './CorrectionContext';

const SpeciesPage = ({ slug }) => {
  const [response, setResponse] = useState({})
  const [correction, setCorrection] = useState({})
  const [edit, setEdit] = useState(false)

  const toggleEdit = () => {
    setEdit(!edit)
  }

  const setField = (field, value) => {
    setCorrection({correction, [field]: value})
  }

  useEffect(() => {
    async function fetchData() {
      const r = await axios.get(`/api/v1/species/${slug}?token=${temp_token}`)
      setResponse(r.data)
    }
    if (slug) {
      fetchData()
    }
  }, [])

  if (response.data) {
    return <>
      <CorrectionContext.Provider value={{ correction, edit, setField, toggleEdit }}>
        <Species
          species={response.data}
        />
      </CorrectionContext.Provider>
    </>
  } else {
    return (<div>
      <h2>Loading...</h2>
    </div>)
  }
}

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#explore-species-page").length > 0) {
    const domContainer = document.querySelector('#explore-species-page');
    const slug = document.location.pathname.split('/').slice(-1)
    ReactDOM.render(React.createElement(SpeciesPage, { slug: slug[0] }), domContainer);
  }
})
