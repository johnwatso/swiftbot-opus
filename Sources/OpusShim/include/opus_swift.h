#ifndef OPUS_SWIFT_H
#define OPUS_SWIFT_H

#include <opus.h>

int opus_swift_encoder_set_bitrate(OpusEncoder *encoder, opus_int32 bitrate);
int opus_swift_encoder_set_complexity(OpusEncoder *encoder, int complexity);
int opus_swift_encoder_set_vbr(OpusEncoder *encoder, int enabled);
int opus_swift_encoder_set_constrained_vbr(OpusEncoder *encoder, int enabled);
int opus_swift_encoder_set_dtx(OpusEncoder *encoder, int enabled);
int opus_swift_encoder_set_inband_fec(OpusEncoder *encoder, int enabled);
int opus_swift_encoder_set_packet_loss_percentage(OpusEncoder *encoder, int percentage);
int opus_swift_encoder_set_signal(OpusEncoder *encoder, int signal);
int opus_swift_encoder_set_max_bandwidth(OpusEncoder *encoder, opus_int32 bandwidth);
int opus_swift_encoder_get_lookahead(OpusEncoder *encoder, opus_int32 *lookahead);

#endif
