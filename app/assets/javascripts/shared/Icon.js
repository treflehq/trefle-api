import React from 'react'
import clsx from 'clsx'
import ICONS from './icons'

// Renders one of the vendored FontAwesome icons (see ./icons.js) as inline svg,
// replacing the <i className="fad fa-name"> markup the FontAwesome runtime kit
// (all.min.js) used to rewrite in the DOM. See issue #231.
//
// Injects the class straight onto the <svg> tag (rather than wrapping it in a
// span) so .fa-icon sizing rules and any fa-<name> selector apply directly to
// it, matching the markup the Rails IconHelper#fa_icon produces server-side.
const Icon = ({ name, style = 'duotone', className, ...rest }) => {
  const svg = ICONS[style] && ICONS[style][name]
  if (!svg) return null

  const classes = clsx('fa-icon', `fa-${name}`, className)
  const markup = svg.replace('<svg ', `<svg class="${classes}" aria-hidden="true" `)

  // React needs a real DOM node to attach dangerouslySetInnerHTML to; this
  // wrapper is unstyled and carries no class of its own.
  return <span dangerouslySetInnerHTML={{ __html: markup }} {...rest} />
}

export default Icon
