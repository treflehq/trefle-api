import { find, isNil } from "lodash"

export const firstNotNil = (...elts) => {
  return find(elts, (e => !isNil(e)))
}