(ns timelog.commands
  (:refer-clojure :exclude [cmd])
  (:require
    [clojure.core :as cc]))

(defonce cmds (atom {}))

(defn register!
  [cmdname {:keys [cmd args validator]}]
  (swap! cmds assoc
         cmdname
         {:args      args
          :validator validator
          :f         cmd}))

(defn get
  [cmdname]
  (cc/get @cmds cmdname))

(defn help
  []
  nil)
