// Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

package com.digitalasset.platform.sandbox.stores.ledger

import java.time.Instant

import akka.NotUsed
import akka.stream.scaladsl.Source
import com.daml.ledger.participant.state.index.v2.PackageDetails
import com.daml.ledger.participant.state.v2._
import com.digitalasset.daml.lf.data.Ref.{PackageId, Party, TransactionIdString}
import com.digitalasset.daml.lf.language.Ast
import com.digitalasset.daml.lf.transaction.Node.GlobalKey
import com.digitalasset.daml.lf.value.Value
import com.digitalasset.daml.lf.value.Value.AbsoluteContractId
import com.digitalasset.daml_lf.DamlLf.Archive
import com.digitalasset.ledger.api.domain.{LedgerId, PartyDetails}
import com.digitalasset.platform.sandbox.metrics.MetricsManager
import com.digitalasset.platform.sandbox.stores.ActiveContracts.ActiveContract

import scala.concurrent.Future

private class MeteredLedger(ledger: Ledger, mm: MetricsManager) extends Ledger {

  override def ledgerId: LedgerId = ledger.ledgerId

  override def ledgerEntries(offset: Option[Long]): Source[(Long, LedgerEntry), NotUsed] =
    ledger.ledgerEntries(offset)

  override def ledgerEnd: Long = ledger.ledgerEnd

  override def snapshot(): Future[LedgerSnapshot] =
    ledger.snapshot()

  override def lookupContract(
      contractId: Value.AbsoluteContractId): Future[Option[ActiveContract]] =
    mm.timedFuture("Ledger:lookupContract", ledger.lookupContract(contractId))

  override def lookupKey(key: GlobalKey): Future[Option[AbsoluteContractId]] =
    mm.timedFuture("Ledger:lookupKey", ledger.lookupKey(key))

  override def publishHeartbeat(time: Instant): Future[Unit] =
    mm.timedFuture("Ledger:publishHeartbeat", ledger.publishHeartbeat(time))

  override def publishTransaction(
      submitterInfo: SubmitterInfo,
      transactionMeta: TransactionMeta,
      transaction: SubmittedTransaction): Future[SubmissionResult] =
    mm.timedFuture(
      "Ledger:publishTransaction",
      ledger.publishTransaction(submitterInfo, transactionMeta, transaction))

  override def lookupTransaction(
      transactionId: TransactionIdString): Future[Option[(Long, LedgerEntry.Transaction)]] =
    mm.timedFuture("Ledger:lookupTransaction", ledger.lookupTransaction(transactionId))

  override def parties: Future[List[PartyDetails]] =
    mm.timedFuture("Ledger:parties", ledger.parties)

  override def allocateParty(
      party: Party,
      displayName: Option[String]): Future[PartyAllocationResult] =
    mm.timedFuture("Ledger:addParty", ledger.allocateParty(party, displayName))

  override def listLfPackages(): Future[Map[PackageId, PackageDetails]] =
    mm.timedFuture("Ledger:listLfPackages", ledger.listLfPackages())

  override def getLfArchive(packageId: PackageId): Future[Option[Archive]] =
    mm.timedFuture("Ledger:getLfArchive", ledger.getLfArchive(packageId))

  override def getLfPackage(packageId: PackageId): Future[Option[Ast.Package]] =
    mm.timedFuture("Ledger:getLfPackage", ledger.getLfPackage(packageId))

  override def uploadDar(
      knownSince: Instant,
      sourceDescription: String,
      payload: Array[Byte]): Future[UploadDarResult] =
    mm.timedFuture("Ledger:uploadDar", ledger.uploadDar(knownSince, sourceDescription, payload))

  override def close(): Unit = {
    ledger.close()
  }
}

object MeteredLedger {
  def apply(ledger: Ledger)(implicit mm: MetricsManager): Ledger = new MeteredLedger(ledger, mm)
}
