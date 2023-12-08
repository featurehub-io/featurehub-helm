#!/bin/sh
helm upgrade -i pubsub-emulator pubsub-emulator --namespace featurehub --wait
helm upgrade -i featurehub featurehub --set googlepubsub.enabled=true,nats.enabled=false --namespace featurehub