package hdlinfo

import scala.collection.mutable
import scala.reflect.runtime.universe.{typeOf, TypeTag}

import io.circe.{Json, ACursor, HCursor, Decoder, Encoder, DecodingFailure}
import io.circe.syntax._

object Registry {
  type DecoderType = (ACursor) => Decoder.Result[TypedObject]

  private val stringToType: mutable.Map[String, String] = mutable.Map.empty
  private val typeToString: mutable.Map[String, String] = mutable.Map.empty
  private val typeToDecoder: mutable.Map[String, DecoderType] = mutable.Map.empty

  def printRegistered(): Unit = {
    println("=== Registry dump ===")
    println("stringToType:")
    stringToType.foreach { println("  * ", _) }

    println("typeToString:")
    typeToString.foreach { println("  * ", _) }

    println("typeToDecoder:")
    typeToDecoder.foreach { case (a, _) => println("  * ", a) }
  }

  def registerDecoderEncoder[T: TypeTag](implicit
      decoder: Decoder[T],
      encoder: Encoder[T]
  ): Unit = {
    val tpe = typeOf[T].typeSymbol.fullName
    typeToDecoder.get(tpe) match {
      case Some(_) => throw new RuntimeException(f"Type '${tpe}' already has a decoder/encoder!")
      case None => {
        typeToDecoder.addOne(
          Tuple2(
            tpe,
            (c: ACursor) => {
              c.as[T] match {
                case Left(failure) => Left(failure)
                case Right(obj)    => Right(RigidTypedObject(obj) /* uses the encoder */ )
              }
            }
          )
        )
      }
    }
  }

  def registerTypeToString[T: TypeTag](s: String): Unit = {
    val tpe = typeOf[T].typeSymbol.fullName
    typeToString.get(tpe) match {
      case None => typeToString.addOne(tpe -> s)
      case Some(s) =>
        throw new RuntimeException(f"type '${tpe}' is already registered to string '${s}'!")
    }
  }

  def registerStringToType[T: TypeTag](s: String): Unit = {
    stringToType.get(s) match {
      case None => stringToType.addOne(s -> typeOf[T].typeSymbol.fullName)
      case Some(tpe) =>
        throw new RuntimeException(f"string '${s}' is already registered to type '${tpe}'!")
    }
  }

  def register[T: TypeTag](s: String)(implicit decoder: Decoder[T], encoder: Encoder[T]): Unit = {
    registerDecoderEncoder[T]
    registerTypeToString[T](s)
    registerStringToType[T](s)
  }

  def register[T: TypeTag](implicit decoder: Decoder[T], encoder: Encoder[T]): Unit = {
    register[T](typeOf[T].typeSymbol.fullName)
  }

  def getDecoderFromString(s: String): Option[DecoderType] = {
    stringToType.get(s) match {
      case None => None
      case Some(value) => {
        typeToDecoder.get(value) match {
          case None        => None
          case Some(value) => Some(value)
        }
      }
    }
  }

  def getStringFromType[T: TypeTag]: Option[String] = {
    stringToType.get(typeOf[T].typeSymbol.fullName) match {
      case None    => None
      case Some(s) => Some(s)
    }
  }

  register[Int]
  register[Long]
  register[BigInt]
  register[Float]
  register[Double]
  register[String]

  // interop with python
  registerStringToType[BigInt]("int")
  registerStringToType[Double]("float")
}

abstract class TypedObject {
  def toJson(): Json
  def getObject(): Any

  def fullTypeName: String

  def maybeGet[T]: Option[T] = {
    try {
      val obj: T = getObject().asInstanceOf[T]
      Some(obj)
    } catch {
      case e: ClassCastException => None
    }
  }

  def get[T] = getObject().asInstanceOf[T]
}

object TypedObject {
  implicit def encodeTypedObject: Encoder[TypedObject] = new Encoder[TypedObject] {
    final def apply(typedObject: TypedObject): Json = {
      typedObject.toJson()
    }
  }

  implicit def decodeTypedObject: Decoder[TypedObject] = new Decoder[TypedObject] {
    def apply(c: HCursor): Decoder.Result[TypedObject] = {
      c.as[String] match {
        case Left(_) => {
          /* not a single string */
          c.downField("typeName").as[String] match {
            case Left(failure) => Left(failure)
            case Right(typeName) => {
              Registry.getDecoderFromString(typeName) match {
                case Some(decoder) => {
                  decoder(c.downField("obj"))
                }
                case None => Left(DecodingFailure(f"unknown type '${typeName}'", c.history))
              }
            }
          }
        }
        case Right(string) => {
          if (string == "null") {
            Right(TypedObject.empty)
          } else {
            Left(DecodingFailure(f"string '${string}' does not represent a TypedObject", c.history))
          }
        }
      }
    }
  }

  def apply[T: Encoder: TypeTag](obj: T): TypedObject = RigidTypedObject(obj)
  def empty: TypedObject = EmptyTypedObject()
}

private case class RigidTypedObject[+T: Encoder: TypeTag](val obj: T) extends TypedObject {
  def toJson(): Json = {
    val typeName = Registry.getStringFromType[T].getOrElse(typeOf[T].typeSymbol.fullName)
    Json.obj(
      "typeName" -> Json.fromString(typeName),
      "obj" -> obj.asJson
    )
  }

  def getObject(): Any = obj

  def fullTypeName: String = typeOf[T].typeSymbol.fullName
}

private case class EmptyTypedObject() extends TypedObject {
  def fullTypeName: String = "null"
  def getObject(): Any = null
  def toJson(): Json = Json.fromString("null")
}

private object PrintRegistered extends App {
  Registry.printRegistered()
}
