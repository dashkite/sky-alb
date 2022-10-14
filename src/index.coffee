import * as Fn from "@dashkite/joy/function"
import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import * as Text from "@dashkite/joy/text"
import { deployStack } from "@dashkite/dolores/stack"
import { getCertificate } from "@dashkite/dolores/acm"
import { getHostedZone } from "@dashkite/dolores/route53"
import { getSecretReference } from "@dashkite/dolores/secrets"
import Templates from "@dashkite/template"

tld = (domain) -> It.join ".", ( Text.split ".", domain )[-2..]

evaluate = Fn.memoize (expression) ->
  [ _operator, _operands... ] = Text.split /\s+/, expression
  switch _operator
    when "$secret"
      getSecretReference Arr.first _operands
    else
      throw new Error "Bad expression: #{expression}"

deployALB = ( description ) ->
  templates = Templates.create "#{__dirname}/../templates"
  templates._.h.registerHelper templateCase: (text) ->
    Text.capitalize Text.camelCase text
  templates._.h.registerHelper add: (value, addend) -> 
    value + addend
  description.tld ?= tld description.domain
  description.certificate = arn: ( await getCertificate description.tld ).arn
  description.zone = id: ( await getHostedZone description.tld ).id
  # TODO possibly make this overrideable
  description.zone1 = "us-east-1a"
  description.zone2 = "us-east-1b"
  if description.headers?
    for header in description.headers
      header.value ?= await evaluate header.expression
  description.tags ?= []
  template = await templates.render "alb/dispatch.yaml", description
  # TODO write conversion function into AWS { Key, Value } format if value is supplied
  deployStack description.name, template

export { deployALB }