# Sample app with independently developed sub-libraries

A common question we receive is how to structure an application that's developed
by multiple independent teams. Typically, in such situation the application is
broken up into several feature tracks, with each team owning one of them. One of
the teams usually owns the infrastructure for the apps, which includes the main
entrypoint that "stitches" the code from multiple feature tracks into the whole
application.

This example emulates a multi-team situation. It is modeled after a train with
a locomotive and two cars - a bike car and a food car. Each of the pieces -
locomotive, bike and food - are individual feature tracks, with locomotive being
the entrypoint that connects the other features (cars) into an app (the train).
There's a service that's shared by all cars - CarMaintenance.
