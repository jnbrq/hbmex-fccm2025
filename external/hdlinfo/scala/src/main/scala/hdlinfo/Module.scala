package hdlinfo

case class Module(
    val name: String,
    val ports: Seq[Port],
    val interfaces: Seq[Interface],
    val args: scala.collection.immutable.Map[String, TypedObject] =
      scala.collection.immutable.Map.empty
)
