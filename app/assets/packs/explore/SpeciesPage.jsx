
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import Species from './Species';
import { useEffect } from 'react';
import CorrectionContext from './CorrectionContext';

const SpeciesPage = ({ slug }) => {
  const [response, setResponse] = useState({})
  const [user, setUser] = useState({})
  const [correction, setCorrection] = useState({})
  const [edit, setEdit] = useState(false)

  const toggleEdit = () => {
    setEdit(!edit)
  }

  const setField = (field, value) => {
    setCorrection({...correction, [field]: value})
  }

  const reset = () => {
    setCorrection({})
    setEdit(false)
  }

  useEffect(() => {
    async function fetchData() {
      const r = await axios.get(`/api/v1/species/${slug}?token=${temp_token}`)
      setResponse(r.data)
    }
    async function fetchUser() {
      const r = await axios.get(`/api/v1/me?token=${temp_token}`)
      setUser(r.data)
    }
    if (slug) {
      fetchData()
      fetchUser()
    }
  }, [])

  if (response.data && user) {
    return <>
      <CorrectionContext.Provider value={{ correction, edit, setField, reset, toggleEdit, user }}>
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

// export default SpeciesPage