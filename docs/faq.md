# Frequently Asked Questions


## What do you mean by BOSH environment?

Working with BOSH, what we call an *environemnt* is the combination of these
components:

1. A BOSH server, who is responsible for driving an underlying
   *automated infrastructure* that provides Virtual Machines and network.
   Such an automated infrastructure is most cases a
   [IaaS](https://en.wikipedia.org/wiki/Infrastructure_as_a_service), and many
   IaaS are supported by BOSH.

2. One or many *deployments* (of distributed software), made on top of those
   VMs and networks. The lifecycle of these deployments is fully managed by
   the BOSH server above. So that you rarely need interacting directly with
   the underlying infrastructure in your day-to-day work.

Tricky detail: the BOSH server above is itself described as a BOSH deployment,
that is managed by the `bosh` command-line tool, because it has the ability to
behave locally like a small BOSH server. This solves the chicken-and-egg
problem when it comes to deploying BOSH with BOSH.


## How is a BOSH deployment described?

With BOSH, your “infrastructure-as-code” is made of one or many *deployments*
and BOSH will take care for converging these towards their desired states.
Each “desire state” is composed of several pieces:

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
