#include "opus_swift.h"

int opus_swift_encoder_set_bitrate(OpusEncoder *encoder, opus_int32 bitrate) {
	return opus_encoder_ctl(encoder, OPUS_SET_BITRATE(bitrate));
}

int opus_swift_encoder_set_complexity(OpusEncoder *encoder, int complexity) {
	return opus_encoder_ctl(encoder, OPUS_SET_COMPLEXITY(complexity));
}

int opus_swift_encoder_set_vbr(OpusEncoder *encoder, int enabled) {
	return opus_encoder_ctl(encoder, OPUS_SET_VBR(enabled));
}

int opus_swift_encoder_set_constrained_vbr(OpusEncoder *encoder, int enabled) {
	return opus_encoder_ctl(encoder, OPUS_SET_VBR_CONSTRAINT(enabled));
}

int opus_swift_encoder_set_dtx(OpusEncoder *encoder, int enabled) {
	return opus_encoder_ctl(encoder, OPUS_SET_DTX(enabled));
}

int opus_swift_encoder_set_inband_fec(OpusEncoder *encoder, int enabled) {
	return opus_encoder_ctl(encoder, OPUS_SET_INBAND_FEC(enabled));
}

int opus_swift_encoder_set_packet_loss_percentage(OpusEncoder *encoder, int percentage) {
	return opus_encoder_ctl(encoder, OPUS_SET_PACKET_LOSS_PERC(percentage));
}

int opus_swift_encoder_set_signal(OpusEncoder *encoder, int signal) {
	return opus_encoder_ctl(encoder, OPUS_SET_SIGNAL(signal));
}

int opus_swift_encoder_set_max_bandwidth(OpusEncoder *encoder, opus_int32 bandwidth) {
	return opus_encoder_ctl(encoder, OPUS_SET_MAX_BANDWIDTH(bandwidth));
}

int opus_swift_encoder_get_lookahead(OpusEncoder *encoder, opus_int32 *lookahead) {
	return opus_encoder_ctl(encoder, OPUS_GET_LOOKAHEAD(lookahead));
}
