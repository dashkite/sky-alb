import { deployStack } from "@dashkite/dolores/stack"
import Templates from "@dashkite/template"

deploy = ( description ) ->
  templates = Templates.create "#{__dirname}/../templates"
  template = await templates.render "main/alb.yaml", description
  deployStack description.name, template

do ->
  Templates.create "#{__dirname}/../templates"

export default deploy