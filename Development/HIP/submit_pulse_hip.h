#pragma once
#include "submit_pulse.h"
#include <cstdio>

namespace hip_reference {
// Borrowed ABI entries; the Network owns stream and keeps the HIP DLL loaded.
// This adapter intentionally supports timed flag0 only. No API export lookup
// or owner selection occurs in Record. The bridge selects owner before enqueue.
struct HipSubmitPulseOps {
 using Handle=void*;
 int owner{};Handle* stream{};
 int(*set_device)(int){};int(*event_create)(Handle*){};
 int(*event_record)(Handle,Handle){};int(*stream_sync)(Handle){};
 int(*event_destroy)(Handle){};
 int select_owner()noexcept{return set_device?set_device(owner):801;}
 int supported(unsigned flags)noexcept{return !flags&&event_create&&event_record&&stream_sync&&event_destroy&&stream&&*stream?0:801;}
 int create(Handle*handle,unsigned flags)noexcept{return flags||!event_create?801:event_create(handle);}
 int record(Handle handle)noexcept{return event_record&&stream?event_record(handle,*stream):801;}
 int drain()noexcept{return stream_sync&&stream?stream_sync(*stream):801;}
 int destroy(Handle handle)noexcept{return event_destroy?event_destroy(handle):801;}
 void log(const char*operation,int status)noexcept{std::fprintf(stderr,"submit_pulse operation=%s status=%d owner=%d\n",operation,status,owner);}
};
}
