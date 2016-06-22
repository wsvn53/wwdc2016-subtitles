# @Author: Ethan
# @Date:   2016-06-22 14:10:53
# @Last Modified by:   Ethan
# @Last Modified time: 2016-06-22 15:26:21

WWDC_SESSION_PREFIX=https://developer.apple.com/videos/play/wwdc2016;
WWDC_LOCAL_DIR=$(basename $WWDC_SESSION_PREFIX);

detect_video_m3u8 () {
	local session_url=$WWDC_SESSION_PREFIX/$SESSION_ID/;
	local session_html=$(curl $session_url);
	local video_url=$(echo "$session_html" | grep .m3u8 | grep $SESSION_ID | head -n1 | sed "s#.*\"\(http://.*m3u8\)\".*#\1#");
	echo "$session_html" | grep .mp4 | grep $SESSION_ID | sed "s#.*\"\(http://.*mp4\).*\".*#\1#" | while read mp4_url; do
		local mp4_filename=$(basename $mp4_url | cut -d. -f1);
		local srt_filename=$mp4_filename.srt;
		echo "> Subtitle local: $WWDC_LOCAL_DIR/$srt_filename" >&2;
		> $WWDC_LOCAL_DIR/$srt_filename;
	done
	echo "$video_url";
	echo "> Video: $video_url" >&2;
}

detect_subtitle_m3u8 () {
	local video_url=$1;
	local subtitle_uri=$(curl $video_url | grep "LANGUAGE=\"English\"" | sed "s#.*URI=\"\(.*\)\"#\1#");
	local subtitle_url=$subtitle_uri;
	[[ "$subtitle_uri" != http* ]] && {
		subtitle_url=$(dirname $video_url)/$subtitle_uri;
	}
	echo "$subtitle_url";
	echo "> Subtitle: $subtitle_url" >&2;
}

download_subtitle_contents () {
	local subtitle_url=$1;
	echo "> Downloading..."

	local subtitle_base_url=$(dirname $subtitle_url);
	curl $subtitle_url | grep "webvtt" | while read webvtt; do
		local subtitle_webvtt=$subtitle_base_url/$webvtt;
		echo "- get $subtitle_webvtt";
		local subtitle_content=$(curl $subtitle_webvtt);
		ls $WWDC_LOCAL_DIR/"$SESSION_ID"_* | while read srt_file; do
			echo "$subtitle_content" >> $srt_file;
		done
	done
}

main () {
	[ ! -d $WWDC_LOCAL_DIR ] && {
		mkdir $WWDC_LOCAL_DIR;
	}

	curl $WWDC_SESSION_PREFIX | grep /videos/play/wwdc2016 | sed "s#.*/videos/play/wwdc2016/\([0-9]\{3\}\).*#\1#" | sort | uniq | while read SESSION_ID; do
		# export SESSION_ID=$;
		local video_url=$(detect_video_m3u8 $SESSION_ID);
		local subtitle_url=$(detect_subtitle_m3u8 $video_url);

		download_subtitle_contents $subtitle_url;
	done
}

main;