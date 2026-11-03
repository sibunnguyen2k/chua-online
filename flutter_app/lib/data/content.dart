import '../models/app_models.dart';

const List<String> buddhistQuotes = [
  'Hận thù không thể dập tắt hận thù, chỉ có từ bi mới dập tắt được hận thù.',
  'Quá khứ đã qua, tương lai chưa tới, hãy sống trọn vẹn trong hiện tại.',
  'Lấy tâm làm gốc, tâm thanh tịnh thì cõi nước thanh tịnh.',
  'Không có con đường nào đến hạnh phúc, hạnh phúc chính là con đường.',
  'Gieo nhân lành gặt quả ngọt; mỗi hành động tử tế là một hạt giống.',
  'Người chiến thắng ngàn quân không bằng người chiến thắng chính mình.',
  'Một ngọn nến có thể thắp sáng ngàn ngọn nến khác mà không hao tổn.',
];

class Mantra {
  const Mantra(this.text, this.hint);
  final String text;
  final String hint;
}

const List<Mantra> mantras = [
  Mantra('Nam mô A Di Đà Phật', 'Niệm Phật cầu an lạc, vãng sinh'),
  Mantra('Nam mô Quan Thế Âm Bồ Tát', 'Danh hiệu đại từ đại bi'),
  Mantra('Nam mô Địa Tạng Vương Bồ Tát', 'Hồi hướng cầu siêu'),
  Mantra('Nam mô Bổn Sư Thích Ca Mâu Ni Phật', 'Đức Phật Thích Ca'),
];

// Nội dung mẫu; hãy đối chiếu/bổ sung từ bản kinh do Tăng đoàn ấn hành trước khi phát hành.
const List<Scripture> scriptures = [
  Scripture(
    title: 'Bát Nhã Tâm Kinh',
    subtitle: 'Hán Việt',
    body:
        'Quán Tự Tại Bồ Tát hành thâm Bát Nhã Ba La Mật Đa thời, chiếu kiến ngũ uẩn giai không, độ nhất thiết khổ ách.\n\n'
        'Xá Lợi Tử! Sắc bất dị không, không bất dị sắc; sắc tức thị không, không tức thị sắc; thọ tưởng hành thức diệc phục như thị.\n\n'
        'Xá Lợi Tử! Thị chư pháp không tướng, bất sinh bất diệt, bất cấu bất tịnh, bất tăng bất giảm.\n\n'
        'Thị cố không trung vô sắc, vô thọ tưởng hành thức; vô nhãn nhĩ tị thiệt thân ý; vô sắc thanh hương vị xúc pháp; vô nhãn giới, nãi chí vô ý thức giới; vô vô minh, diệc vô vô minh tận, nãi chí vô lão tử, diệc vô lão tử tận; vô khổ tập diệt đạo; vô trí diệc vô đắc.\n\n'
        'Dĩ vô sở đắc cố, Bồ đề tát đỏa y Bát Nhã Ba La Mật Đa cố, tâm vô quái ngại; vô quái ngại cố, vô hữu khủng bố, viễn ly điên đảo mộng tưởng, cứu cánh Niết Bàn.\n\n'
        'Tam thế chư Phật y Bát Nhã Ba La Mật Đa cố, đắc A nậu đa la tam miệu tam bồ đề.\n\n'
        'Cố tri Bát Nhã Ba La Mật Đa, thị đại thần chú, thị đại minh chú, thị vô thượng chú, thị vô đẳng đẳng chú, năng trừ nhất thiết khổ, chân thực bất hư.\n\n'
        'Cố thuyết Bát Nhã Ba La Mật Đa chú, tức thuyết chú viết:\n\nYết đế yết đế, ba la yết đế, ba la tăng yết đế, bồ đề tát bà ha.',
  ),
  Scripture(
    title: 'Tam Quy Y',
    subtitle: 'Kệ quy y Tam Bảo',
    body:
        'Tự quy y Phật, đương nguyện chúng sanh, thể giải đại đạo, phát vô thượng tâm.\n\n'
        'Tự quy y Pháp, đương nguyện chúng sanh, thâm nhập kinh tạng, trí huệ như hải.\n\n'
        'Tự quy y Tăng, đương nguyện chúng sanh, thống lý đại chúng, nhất thiết vô ngại.',
  ),
  Scripture(
    title: 'Hồi Hướng Công Đức',
    subtitle: 'Bài nguyện cuối thời khoá',
    body:
        'Nguyện đem công đức này,\nHướng về khắp tất cả,\nĐệ tử và chúng sinh,\nĐều trọn thành Phật đạo.',
  ),
];
