# Frequently Asked Questions


## What do we mean by BOSH environment?

Working with BOSH, what we call an *environemnt* is the combination of these
components:

1. A BOSH server, who is responsible for driving an underlying automated
   infrastructure (most of the time a IaaS, many of those are supported).

2. One or many *deployments* (of distributed software), made on that uderlying
   infrastructure. The lifecycle of these deployments is fully managed by the
   BOSH server above. So that you rarely need interacting directly with the
   underlying infrastructure in your day-to-day work.

Tricky detail: the BOSH server above is itself described as a BOSH deployment,
that is managed by the `bosh` command-line tool, because it has the ability to
behave locally like a small BOSH server. This solves the chicken-and-egg
problem when it comes to deploying BOSH with BOSH.


## How is a BOSH deployment described?

With BOSH v2, your “infrastructure-as-code” is made of one or many
*deployments* and BOSH will take care for converging these towards a desired
state. Each of these desired states are composed of several pieces:

1. A base deployment manifest (usually provided by a 3rd party `*-deployment`
   Git repository).

2. Any standard set patches to be applied to the base deployment manifest,
   that will implement specific features that are relevant to your context.
   These are expressed as *operation files* (from the 3rd party `*-deployment`
   repository).

3. Possibly some custom operation files that you'll provide in order to
   implement non-standard variants to the base deployment.

4. Custom values for any variables that need being defined. These will be
   provided by you, and shall reflect your use-cases.

Those 4 types of pieces are tied toghether when they get passed as arguments
to the BOSH commands that are involved in the day-to-day work with the
deployments. In the end, these arguments are part of the desired state that
needs to be captured in Git.
