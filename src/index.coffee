import * as Arr from "@dashkite/joy/array"
import * as It from "@dashkite/joy/iterable"
import * as Text from "@dashkite/joy/text"
import { deployStack } from "@dashkite/dolores/stack"
import { getCertificate } from "@dashkite/dolores/acm"
import { getHostedZone } from "@dashkite/dolores/route53"
import { getSecretReference } from "@dashkite/dolores/secrets"
import Templates from "@dashkite/template"

tld = (domain) -> It.join ".", ( Text.split ".", domain )[-2..]

deployALB = ( description ) ->
  templates = Templates.create "#{__dirname}/../templates"
  description.sname = Text.capitalize Text.camelCase description.name
  description.tld ?= tld description.domain
  description.certificate = arn: ( await getCertificate description.tld ).arn
  description.zone = id: ( await getHostedZone description.tld ).id
  # TODO possibly make this overrideable
  description.zone1 = "us-east-1a"
  description.zone2 = "us-east-1b"
  # TODO replace with real key
  description.apiKey = await getSecretReference description["api-key"]
  description.tags ?= []
  console.log description
  template = await templates.render "alb/dispatch.yaml", description
  # TODO write conversion function into AWS { Key, Value } format if value is supplied
  console.log template
  deployStack description.name, template

export { deployALB }