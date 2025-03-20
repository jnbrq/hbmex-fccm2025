// See README.md for license details.

ThisBuild / scalaVersion := "2.13.12"
ThisBuild / version := "0.1.0"
ThisBuild / organization := "hdlstuff"

val circeVersion = "0.14.1"

lazy val root = (project in file("."))
  .settings(
    name := "hdlinfo",
    libraryDependencies ++= Seq(
      "org.scala-lang" % "scala-reflect" % scalaVersion.value,
      "io.circe" %% "circe-core" % circeVersion,
      "io.circe" %% "circe-generic" % circeVersion,
      "io.circe" %% "circe-parser" % circeVersion
    ),
    scalacOptions ++= Seq(
      "-Ymacro-annotations"
    )
  )
