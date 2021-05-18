//the function is used to connect vehicle trajectories
//the max gap is defined as "FILL_LEN"
//the max distance of locations of a vehicle in two connected
//frames is defined as DET, with DET.x = max distance in x direction
// and DET.y in y direction
//vehicles location is stored in container vector<Vehi*>
/*

class Vehi {

public:
	Vehi() {
	}
	Vehi(int n, cv::Rect rect, Mat m, int IDnum);
	Vehi(vector<int> , int IDnum, int, int);
	Vehi(vector<int> c, int IDnum, int ws, int hs, float spd, float acc, float hw, float gt, float gx, float gy);
	Vehi(vector<float> c, int IDnum, float ws, float hs, float spd, float acc, float hw, float gt, float gx, float gy);
	void addrect(int n, cv::Rect rect, Mat m);
	bool similairty(cv::Rect rect, Mat fi); 
	bool missed(int fnum);
	bool deletecri(Mat frame);
	bool overlap(Rect);

public:
	int ID;
	vector<vector<int>> points;
	vector<vector<float>> rp;
	vector<vector<float>> vtgps;
	vector<vector<float>> vspdacc;
	vector<float> vhw;
	int predx, predy;
	int width, height;
	float rw, rh;
	int predlane;
	int orilane;
	double spdx = 0.0, spdy = 15.0;
	Mat img;
	int missingnum = 1;
	int type = 2;
	int startfnum = 0;
	int closevnum = 0;
	vector<set<int>> closevehs;
	vector<int> pcdvehid;
	vector<int> vln;
	vector<Point2f> tempsz;//h,w
	vector<Point2f> vlocs;
	vector<Point2f> spdacc;
};





*/
void post_process_connect(int FILL_LEN, Point2f DET) {////////////////////////////////!!!!!!!!!!!!!!!!!!!!!!!!!!!////////////////////////////////!!!!!!!!!!!!!!!!!!!!!!!!!!!

	int y_bound = 8000, t_range = FILL_LEN, v_range = 5000, size_range = 10;
	double acc_bound = 100, spd, spd_int = 60, int_def = 30;
	double maxspd = 210;//mph;
	double disint = DET.y;
	double dy_def = 50 * 1.4667 / 30, dy0, dy, dx0 = 4, dx;
	double x_dif, y_dif;
	/*
	vector<Point2f> tempsz;//h,w
	vector<Point2f> vlocs;
	vector<Point2f> spdacc;
	*/
	vector<Vehi*> vehs = VEHS;
	for (int i = 0; i < vehs.size(); i++) {////////////////////////////////!!!!!!!!!!!!!!!!!!!!!!!!!!!
		vector<Point2f> &loc = vehs[i]->vlocs;
		if (loc.back().y < y_bound) {
			if (loc.size() < FILL_LEN)
				continue;
			else {
				spd_int = min(loc.size(), int_def);
				int z = loc.size();
				spd = (-loc[z - spd_int].y + loc[z - 1].y) / (spd_int - 1);
				dy0 = spd;
			}
			//if (loc[0].y > 7300 && loc[0].y < 7400)
			//cout << "here";
			bool found = 1;
			while (found && loc.back().y < y_bound) {
				int t0 = vehs[i]->startfnum + loc.size();
				found = 0;
				for (int t = t0; t < t0 + t_range; t++) {
					double dt = t - t0 + 1;
					Point2f fp = loc.back() + Point2f(0, dy0);
					x_dif = DET.x;
					y_dif = disint + min(disint*0.5, 0.5 * acc_bound * (dt / 30.0) * (dt / 30.0));
					Point2f dpmin{ 100,100 };
					int j0 = 0;
					int i0 = i;
					while (vehs[i0]->startfnum < t && i0 < vehs.size())
						i0++;
					if (i0 == vehs.size())
						break;
					for (int j = i0; j < i0 + v_range && j < vehs.size(); j++) {
						if (vehs[j]->startfnum < t)
							continue;
						if (vehs[j]->startfnum > t)
							break;
						Point2f vp = vehs[j]->vlocs[0];
						Point2f dp = (vp - fp);
						if (abs(dp.x) < abs(dpmin.x) && (abs(dp.y) < abs(dpmin.y))) {// || (dp.y < 0 && dp.y > dpmin.y))
							j0 = j;
							dpmin = dp;
						}
					}
					if ((abs(dpmin.x) < x_dif || (fp.x < -20 && abs(dpmin.x) < 2 * x_dif)) && dpmin.y > 0 - y_dif && dpmin.y < y_dif) {
						loc.insert(loc.end(), vehs[j0]->vlocs.begin(), vehs[j0]->vlocs.end());
						vehs[i]->tempsz.insert(vehs[i]->tempsz.end(), vehs[j0]->tempsz.begin(), vehs[j0]->tempsz.end());
						vehs.erase(vehs.begin() + j0);
						found = 1;
						break;
					}
					else {
						loc.push_back(fp);
						vehs[i]->tempsz.insert(vehs[i]->tempsz.end(), vehs[i]->tempsz.back());
						if (t == t0 + t_range - 1) {
							int nn = t_range - 1;
							while (nn--)
							{
								loc.pop_back();
								vehs[i]->tempsz.pop_back();
							}
						}
					}
				}
			}
		}
	}
	VEHS = vehs;
}
