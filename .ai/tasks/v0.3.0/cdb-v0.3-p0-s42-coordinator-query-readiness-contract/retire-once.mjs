// Task-owned operation client. Imported by offline fixtures; live adapter is
// separate and requires an explicit later approval receipt. Never retries Stop.
export async function retireOnce(io, grant) {
  const report={stage:'PREFLIGHT',stop_requests:0,operation_reads:0,status:'NOT_ESTABLISHED'};
  try {
    const owner=await io.inspect(grant);
    report.identity=owner.identity;
    const id=io.newId();
    const request={command:'watcher',action:'Stop',expected_lifecycle_id:owner.coordinatorLifecycle,
      request_id:id,manager_action_id:id,protocol_version:1,client_kind:'s42-owned-retirement'};
    io.assertSelection();
    report.stage='STOP_ADMISSION';report.stop_requests++;
    let response=await io.request(request);
    let operationId=null;
    const started=io.now();
    for(;;) {
      if(!response)throw new Error('RESPONSE_UNAVAILABLE_NO_REPLAY');
      io.validateOwner(response.status);
      if(response.ok!==true||response.accepted!==true) {
        report.server_error_code=io.safeCode(response.error_code);throw new Error('SERVER_REJECTED');
      }
      const op=response.operation;
      if(!op||typeof response.operation_id!=='string'||!/^[a-f0-9]{32}$/.test(response.operation_id)
        ||op.operation_id!==response.operation_id||op.manager_action_id!==id||op.name!=='watcher:Stop'
        ||op.owner_epoch!==owner.ownerEpoch)throw new Error('OPERATION_CORRELATION_MISMATCH');
      if(operationId&&operationId!==response.operation_id)throw new Error('OPERATION_ID_CHANGED');
      operationId=response.operation_id;report.operation_id=operationId;
      report.operation_state=op.state;report.stage='OPERATION_OBSERVATION';
      if(response.pending!==true) {
        if(op.state!=='completed'||response.result?.exit_code!==0||response.result?.timed_out===true
          ||response.result?.output_overflow===true||response.result?.output_drain_incomplete===true)
          throw new Error('TERMINAL_OPERATION_NOT_SUCCESSFUL');
        break;
      }
      if(!['queued','running'].includes(op.state))throw new Error('INVALID_PENDING_STATE');
      if(report.operation_reads>=90||io.now()-started>=180000)throw new Error('OBSERVATION_BUDGET_EXHAUSTED_NO_REPLAY');
      await io.pause(2000);io.assertSelection();
      report.operation_reads++;
      response=await io.request({command:'operation',operation_id:operationId,request_id:io.newId(),protocol_version:1});
    }
    report.stage='STOP_POSTCONDITION';io.assertSelection();
    const post=await io.verifyStopped(owner);
    report.postcondition=post;
    if(post.recorded_process_absent!==true||post.coordinator_state_absent!==true||post.manual_stopped!==true)
      throw new Error('STOP_POSTCONDITION_NOT_ESTABLISHED');
    report.status='OWNED_STOP_CONFIRMED';report.stage='COMPLETE';
  }catch(error){report.status='STOPPED_NO_REPLAY';report.stop_code=io.safeCode(error.message);}
  return report;
}
