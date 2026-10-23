import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import '../models/enums.dart';
import '../models/evento_model.dart';
import '../models/iglesia_model.dart';
import '../models/ministerio_model.dart';
import '../models/user_model.dart';

/// Copias modificadas de los modelos (son inmutables) para el Modo Demo.
abstract final class DemoCopias {
  static IglesiaModel iglesia(
    IglesiaModel i, {
    DocumentReference? creadoPor,
    EstadoLogico? estadoLogico,
    EstadoAprobacion? estadoAprobacion,
    DocumentReference? liderUidRef,
    String? liderNombreTexto,
    EstadoAdministracion? estadoAdministracion,
    VerificacionDenominacion? verificacionDenominacion,
  }) {
    return IglesiaModel(
      idIglesia: i.idIglesia,
      nombre: i.nombre,
      denominacion: i.denominacion,
      tipo: i.tipo,
      ubicacion: i.ubicacion,
      direccionTexto: i.direccionTexto,
      linkVirtual: i.linkVirtual,
      pais: i.pais,
      localidad: i.localidad,
      estadoAprobacion: estadoAprobacion ?? i.estadoAprobacion,
      oficialidad: i.oficialidad,
      liderNombreTexto: liderNombreTexto ?? i.liderNombreTexto,
      aprobadorNombreTexto: i.aprobadorNombreTexto,
      liderUidRef: liderUidRef ?? i.liderUidRef,
      creadoPor: creadoPor ?? i.creadoPor,
      estadoLogico: estadoLogico ?? i.estadoLogico,
      creadoEn: i.creadoEn,
      estadoAdministracion: estadoAdministracion ?? i.estadoAdministracion,
      origen: i.origen,
      osmId: i.osmId,
      verificacionDenominacion:
          verificacionDenominacion ?? i.verificacionDenominacion,
      criterioOsm: i.criterioOsm,
    );
  }

  static UserModel usuario(UserModel u, {RolGlobal? rolGlobal}) {
    return UserModel(
      uid: u.uid,
      email: u.email,
      nombreCompleto: u.nombreCompleto,
      rolGlobal: rolGlobal ?? u.rolGlobal,
      estadoCuenta: u.estadoCuenta,
      puntosTotales: u.puntosTotales,
      rachaActual: u.rachaActual,
      insigniasDesbloqueadas: u.insigniasDesbloqueadas,
      perfilPublico: u.perfilPublico,
      creadoEn: u.creadoEn,
    );
  }

  static EventoModel evento(
    EventoModel e, {
    DocumentReference? creadoPor,
    EstadoLogico? estadoLogico,
    EstadoAprobacion? estadoAprobacion,
    DateTime? creadoEn,
  }) {
    return EventoModel(
      idEvento: e.idEvento,
      tipoActividad: e.tipoActividad,
      titulo: e.titulo,
      categoria: e.categoria,
      descripcion: e.descripcion,
      iglesiaRef: e.iglesiaRef,
      ministerioRef: e.ministerioRef,
      fechaHoraInicio: e.fechaHoraInicio,
      fechaHoraFin: e.fechaHoraFin,
      esRecurrente: e.esRecurrente,
      patronRecurrencia: e.patronRecurrencia,
      esVirtual: e.esVirtual,
      linkVirtual: e.linkVirtual,
      imagenUrl: e.imagenUrl,
      estadoAprobacion: estadoAprobacion ?? e.estadoAprobacion,
      estadoLogico: estadoLogico ?? e.estadoLogico,
      creadoPor: creadoPor ?? e.creadoPor,
      creadoEn: creadoEn ?? e.creadoEn,
    );
  }

  static MinisterioModel ministerio(
    MinisterioModel m, {
    DocumentReference? creadoPor,
    EstadoLogico? estadoLogico,
    EstadoAprobacion? estadoAprobacion,
  }) {
    return MinisterioModel(
      idMinisterio: m.idMinisterio,
      nombre: m.nombre,
      iglesiaRef: m.iglesiaRef,
      tipoUbicacion: m.tipoUbicacion,
      ubicacionPropia: m.ubicacionPropia,
      linkVirtual: m.linkVirtual,
      denominacion: m.denominacion,
      pais: m.pais,
      localidad: m.localidad,
      coordinadorRef: creadoPor ?? m.coordinadorRef,
      estadoAprobacion: estadoAprobacion ?? m.estadoAprobacion,
      creadoPor: creadoPor ?? m.creadoPor,
      estadoLogico: estadoLogico ?? m.estadoLogico,
      creadoEn: m.creadoEn,
    );
  }
}
