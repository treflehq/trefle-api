
import { map } from 'lodash';
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import { useEffect } from 'react';

const Species = ({ species }) => {

  return (<div>
    <div className="columns">
      <div className="column is-4">
        <aside className="species-side-image" style={{backgroundImage: `url(${ species.image_url })`}}></aside>
      </div>
      <div className="column is-8">
        <section className="hero">
          <div className="hero-body">
            <div className="container">
              <h1 className="title is-1">
                { species.scientific_name }
              </h1>
              <h2 className="subtitle">
                { species.common_name || 'No common name' }
              </h2>
              <p className="subtitle">
                <i className="fad fa-book has-text-success"></i> { species.author || 'No author' } { species.year || 'No year' } - <i>{ species.bibliography || 'No bibliography' }</i>
                <br />
                { species.observations }
              </p>
            </div>
          </div>
        </section>
      </div>
    </div>
    <div className="columns">
      <div className="column is-2">
        <br />
        <br />
        <aside className="menu">
          <ul className="menu-list">
            <li><a href="#specifications">Specifications</a></li>
            <li><a href="#images">Images</a></li>
            <li><a href="#synonyms">Synonyms</a></li>
          </ul>
        </aside>
      </div>
      <div className="column is-10">
        <section className="section content" id="specifications">
          <h1 className="title is-4 ">
            <i className="fad fa-cog has-text-success"></i> Specifications
          </h1>
        </section>

        <section className="section content" id="specifications">
          <h1 className="title is-4 ">
            <i className="fad fa-image has-text-success"></i> Images
          </h1>
          { map(species.images, (images, itype) => {
            if (images.length == 0) {
              return null
            }
            return (<div key={itype}>
              <h2 className="title is-5 ">
                <i className="fad fa-image has-text-success"></i> { itype }
              </h2>
              <div className="columns is-multiline">
                {images.map(i => <div key={i.id} className="column is-4">
                  <img src={i.image_url} />
                </div>)}
              </div>
            </div>)
          }) }
        </section>
      </div>
    </div>
  </div>)
}

export default Species