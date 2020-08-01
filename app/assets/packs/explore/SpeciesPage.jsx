
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import Species from './Species';
import { useEffect } from 'react';

const SpeciesPage = ({ slug }) => {
  const [response, setresponse] = useState({})

  useEffect(() => {
    async function fetchData() {
      const r = await axios.get(`/api/v1/species/${slug}?token=${temp_token}`)
      setresponse(r.data)
    }
    fetchData()
  }, [])

  if (response.data) {
    return <Species species={response.data} />
  } else {
    return (<div>
      <h2>Loading...</h2>
    </div>)
  }
}

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#explore-species-page").length > 0) {
    const domContainer = document.querySelector('#explore-species-page');
    ReactDOM.render(React.createElement(SpeciesPage, { slug: 'quercus-rotundifolia' }), domContainer);
  }
})
